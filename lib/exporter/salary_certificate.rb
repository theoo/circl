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

  class SalaryCertificate < Exporter::Resource

    def initialize(options = {})
      super

      @options = options

      @options[:date] ||= Time.now.to_date
      @options.merge(options)
    end

    def convert(salaries)
      salaries = salaries.order("salaries.from ASC, salaries.to ASC")
      references = salaries.map(&:reference).uniq

      cert_avs = salaries.map(&:avs_group).flatten.empty? ? 0 : salaries.map(&:avs_group).flatten.map(&:employee_value).sum.to_f
      cert_lpp = salaries.map(&:lpp_group).flatten.empty? ? 0 : salaries.map(&:lpp_group).flatten.map(&:employee_value).sum.to_f
      cert_is  = salaries.map(&:is_group).flatten.empty? ? 0 : salaries.map(&:is_group).flatten.map(&:employee_value).sum.to_f

      {
        # eLohnausweisSSK
        :cert_year                          => salaries.first.year, # 3 Année impératif D
        :cert_from                          => salaries.first.from.strftime("%d.%m.%Y"), # 4 du (date) impératif E
        :cert_to                            => salaries.last.to.strftime("%d.%m.%Y"), # 5 au (date) impératif E
        :cert_transport                     => references.map(&:cert_transport).sum.to_f, # 6 Transport gratuit entre le domicile et le lieu de F travail
        :cert_food                          => references.map(&:cert_food).sum.to_f, # 7 Repas à la cantine / chèques-repas G
        :cert_value                         => salaries.map(&:gross_pay).sum.to_f, # 8 Salaire / Rente (montant) 1.0
        :cert_logding                       => references.map(&:cert_logding).sum.to_f, # 9 Prestations salariales accessoires : Pension lo- 2.1 gement (montant)
        :cert_misc_salary_car               => references.map(&:cert_misc_salary_car).sum.to_f, # 10 Prestations salariales accessoires : Part privée voitu- 2.2 re de service (montant)
        :cert_misc_salary_other_title       => references.map(&:cert_misc_salary_other_title).sum.to_f, # 11 Prestations salariales accessoires : Autres - Genre 2.3 (texte)
        :cert_misc_salary_other_value       => references.map(&:cert_misc_salary_other_value).sum.to_f, # 12 Prestations salariales accessoires : Autres (montant) 2.3
        :cert_non_periodic_title            => references.map(&:cert_non_periodic_title).sum.to_f, # 13 Prestations non périodiques - Genre (texte) 3.0
        :cert_non_periodic_value            => references.map(&:cert_non_periodic_value).sum.to_f, # 14 Prestations non périodiques (montant) 3.0
        :cert_capital_title                 => references.map(&:cert_capital_title).sum.to_f, # 15 Prestations en capital - Genre (texte) 4.0
        :cert_capital_value                 => references.map(&:cert_capital_value).sum.to_f, # 16 Prestations en capital (montant) 4.0
        :cert_participation                 => references.map(&:cert_participation).sum.to_f, # 17 Droits de participation selon annexe (montant) 5.0
        :cert_compentation_admin_members    => references.map(&:cert_compentation_admin_members).sum.to_f, # 18 Indemnités des membres de l'administration (mon- 6.0 tant)
        :cert_misc_other_title              => references.map(&:cert_misc_other_title).sum.to_f, # 19 Autres prestations - Genre (texte) 7.0
        :cert_misc_other_value              => references.map(&:cert_misc_other_value).sum.to_f, # 20 Autres prestations (montant) 7.0
        :cert_avs_ac_aanp                   => cert_avs, # 21 Cotisations AVS/AI/APG/AC/AANP 2e 9.0
        :cert_lpp                           => cert_lpp, # 22 Prévoyance professionnelle pilier : Cotisations or- 10.1 dinaires (montant)
        :cert_buy_lpp                       => references.map(&:cert_buy_lpp).sum.to_f, # 23 Prévoyance professionnelle 2e pilier : Cotisations 10.2 pour le rachat
        :cert_is                            => cert_is, # 24 Retenue de l'impôt à la source (montant) 12.0
        :cert_alloc_traveling               => references.map(&:cert_alloc_traveling).sum.to_f, # 25 Allocations pour frais : Frais effectifs – case de 13.1 contrôle (« x » resp. laisser vide)
        :cert_alloc_food                    => references.map(&:cert_alloc_food).sum.to_f, # 26 Allocations pour frais : voyage repas nuitées 13.1.1 (montant)
        :cert_alloc_other_actual_cost_title => references.map(&:cert_alloc_other_actual_cost_title).sum.to_f, # 27 Allocations pour frais : Frais effectifs - Autres - Genre 13.1.2 (texte)
        :cert_alloc_other_actual_cost_value => references.map(&:cert_alloc_other_actual_cost_value).sum.to_f, # 28 Allocations pour frais : Frais effectifs - Autres (mon- 13.1.2 tant)
        :cert_alloc_representation          => references.map(&:cert_alloc_representation).sum.to_f, # 29 Allocations pour frais : Frais forfaitaires - Représenta- 13.2.1 tion (montant)
        :cert_alloc_car                     => references.map(&:cert_alloc_car).sum.to_f, # 30 Allocations pour frais : Frais forfaitaires - Voiture 13.2.2 (montant)
        :cert_alloc_other_fixed_fees_title  => references.map(&:cert_alloc_other_fixed_fees_title ).sum.to_f, # 31 Allocations pour frais : Frais forfaitaires - Autres - 13.2.3 Genre (texte)
        :cert_alloc_other_fixed_fees_value  => references.map(&:cert_alloc_other_fixed_fees_value ).sum.to_f, # 32 Allocations pour frais : Frais forfaitaires - Autres 13.2.3 (montant)
        :cert_formation                     => references.map(&:cert_formation).sum.to_f, # 33 Contributions au perfectionnement 13.3
        :cert_others_title                  => references.map(&:cert_others_title).sum.to_f, # 34 Autres prestations salariales accessoires - Genre 14.0 (texte)
        :cert_notes                         => references.map(&:cert_notes).sum.to_f, # 35 Observations (texte) 15.0
      }
    end
  end

end