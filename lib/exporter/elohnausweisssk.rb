# encoding: utf-8
=begin
  CIRCL Directory
  Copyright (C) 2011 Complex IT sàrl

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU Affero General Public License as
  published by the Free Software Foundation, either version 3 of the
  License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU Affero General Public License for more details.

  You should have received a copy of the GNU Affero General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
=end

module Exporter

  class Elohnausweisssk < Base

    def initialize(resource)
      super
      @csv_options[:col_sep] = ";"

      @circl_owner = Person.find ApplicationSetting.value(:me)

      @employer_cols = [ 1,                   # 1 1 (fixe pour l’employeur) impératif
                         :person_name,        # 2 Nom impératif
                         :person_address,     # 3 Rue
                         nil,                 # 4 Boîte postale
                         :person_postal_code, # 5 Code postal impératif, numérique
                         :person_city,        # 6 Lieu impératif
                         :person_country,     # 7 Pays
                         :person_phone,       # 8 Téléphone
                         :person_first_name,  # 9 Personne de contact : prénom impératif
                         :person_last_name,   # 10 Personne de contact : nom impératif
                         :person_phone        # 11 Personne de contact : téléphone impératif
                       ]

      @employee_cols = [ 2,                   # 1 2 (fixe pour l’employé) impératif
                         nil,                 # 2 Numéro AVS numéro AVS valable dans le for- 1) mat « xxx.xx.xxx.xxx »
                         :person_avs_number,  # 3 Nouveau numéro AVS nouveau numéro d’assuré valable 1) dans le format « xxx.xxxx.xxxx.xx »
                         :person_birth_date,  # 4 Date de naissance date valable après 1890 et avant 1) aujourd’hui
                         :person_gender,      # 5 Sexe impératif, « M » pour masculin resp. « F » pour féminin
                         :person_first_name,  # 6 Prénom impératif
                         :person_last_name,   # 7 Nom impératif
                         :person_address,     # 8 Rue
                         nil,                 # 9 Boîte postale
                         :person_postal_code, # 10 Code postal impératif, numérique
                         :person_city,        # 11 Lieu impératif
                         :person_country      # 12 Pays
                       ]

      @certificates_cols = [ 3,                                   # 1 3 (fixe pour le certificat de salaire) impératif -
                             "SR",                                # 2 Type (« SR » pour les certificats de salaire, impératif A resp. B « AR » pour les attestations de rentes)
                             :cert_year,                          # 3 Année impératif D
                             :cert_from,                          # 4 du (date) impératif E
                             :cert_to,                            # 5 au (date) impératif E
                             :cert_transport,                     # 6 Transport gratuit entre le domicile et le lieu de F travail
                             :cert_food,                          # 7 Repas à la cantine / chèques-repas G
                             :cert_value,                         # 8 Salaire / Rente (montant) 1.0
                             :cert_logding,                       # 9 Prestations salariales accessoires : Pension, lo- 2.1 gement (montant)
                             :cert_misc_salary_car,               # 10 Prestations salariales accessoires : Part privée voitu- 2.2 re de service (montant)
                             :cert_misc_salary_other_title,       # 11 Prestations salariales accessoires : Autres - Genre 2.3 (texte)
                             :cert_misc_salary_other_value,       # 12 Prestations salariales accessoires : Autres (montant) 2.3
                             :cert_non_periodic_title,            # 13 Prestations non périodiques - Genre (texte) 3.0
                             :cert_non_periodic_value,            # 14 Prestations non périodiques (montant) 3.0
                             :cert_capital_title,                 # 15 Prestations en capital - Genre (texte) 4.0
                             :cert_capital_value,                 # 16 Prestations en capital (montant) 4.0
                             :cert_participation,                 # 17 Droits de participation selon annexe (montant) 5.0
                             :cert_compentation_admin_members,    # 18 Indemnités des membres de l'administration (mon- 6.0 tant)
                             :cert_misc_other_title,              # 19 Autres prestations - Genre (texte) 7.0
                             :cert_misc_other_value,              # 20 Autres prestations (montant) 7.0
                             :cert_avs_ac_aanp,                   # 21 Cotisations AVS/AI/APG/AC/AANP 2e 9.0
                             :cert_lpp,                           # 22 Prévoyance professionnelle pilier : Cotisations or- 10.1 dinaires (montant)
                             :cert_buy_lpp,                       # 23 Prévoyance professionnelle 2e pilier : Cotisations 10.2 pour le rachat
                             :cert_is,                            # 24 Retenue de l'impôt à la source (montant) 12.0
                             :cert_alloc_traveling,               # 25 Allocations pour frais : Frais effectifs – case de 13.1 contrôle (« x » resp. laisser vide)
                             :cert_alloc_food,                    # 26 Allocations pour frais : voyage, repas, nuitées 13.1.1 (montant)
                             :cert_alloc_other_actual_cost_title, # 27 Allocations pour frais : Frais effectifs - Autres - Genre 13.1.2 (texte)
                             :cert_alloc_other_actual_cost_value, # 28 Allocations pour frais : Frais effectifs - Autres (mon- 13.1.2 tant)
                             :cert_alloc_representation,          # 29 Allocations pour frais : Frais forfaitaires - Représenta- 13.2.1 tion (montant)
                             :cert_alloc_car,                     # 30 Allocations pour frais : Frais forfaitaires - Voiture 13.2.2 (montant)
                             :cert_alloc_other_fixed_fees_title,  # 31 Allocations pour frais : Frais forfaitaires - Autres - 13.2.3 Genre (texte)
                             :cert_alloc_other_fixed_fees_value,  # 32 Allocations pour frais : Frais forfaitaires - Autres 13.2.3 (montant)
                             :cert_formation,                     # 33 Contributions au perfectionnement 13.3
                             :cert_others_title,                  # 34 Autres prestations salariales accessoires - Genre 14.0 (texte)
                             :cert_notes                          # 35 Observations (texte) 15.0
                           ]
    end

    # override map_item to convert dates
    # FIXME: this should be global in application_settings
    def map_item(i, cols)
      validate_requirements i, cols

      cols.map do |c|
        if c.is_a? Symbol
          if i[c].is_a? Date
            i[c].strftime("%d.%m.%Y")
          else
            i[c]
          end
        else
          c
        end
      end
    end

    def export(salaries)
      CSV.generate(@csv_options) do |csv|

        ## employer
        # first line describes the employer
        employer_resource = Exporter::Employer.new
        ci = employer_resource.convert(@circl_owner)
        csv << map_item(ci, @employer_cols)

        ## employee and certificates
        # second to n line describes employees and its certificates
        employee_resource = Exporter::Employee.new
        cert_resource = Exporter::SalaryCertificate.new

        # map people referenced in salaries
        @employees = salaries.all.map(&:person).uniq

        # append employees to CSV file
        @employees.each do |employee|
          e = employee_resource.convert(employee)
          csv << map_item(e, @employee_cols)

          c = cert_resource.convert(salaries.where(:person_id => employee.id))
          csv << map_item(c, @certificates_cols)
        end

      end

    end

  end

end
